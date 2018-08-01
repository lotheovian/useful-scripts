#!/bin/bash

set -e
if [ $# -lt 1 ] || [ $# -gt 2 ] 
then echo "usage: $0 svc_name [maven/docker]"
     exit 1
fi

artifact_url="artifact/url"
product_url="your.url.here.com"
ecs_addr="myuuidhere.dkr.ecr.zone.amazonaws.com"
svc_name=$1
release_type=$2 # maven/docker

ci_step=$CI_JOB_STAGE
branch_name="$CI_COMMIT_REF_NAME"

if [ $branch_name == "master" ]
then release_env=release
     docker_version="latest"
     kube_context=$product_url
elif [ $branch_name == "staging" ] || \
     [ $branch_name == "devel" ]
then echo releasing $svc_name to $branch_name
     release_env="$branch_name"
     docker_version="$release_env"
     kube_context=$branch_name.$product_url
else echo non-release branch $branch_name
     release_env=devel
fi

echo ci_step:$ci_step
echo build_stage:$release_env
echo proj_name:$CI_PROJECT_NAME
echo svc_name:$svc_name
echo docker_version:$docker_version

if [ $ci_step == "compile" ]
then mvn clean
     mvn compile -U -P$release_env
elif [ $ci_step == "test" ]
then mvn test -U -P$release_env
elif [ $ci_step == "package" ]
then rm -f target/*.jar           #gitlab CI caching will keep old builds, clean these out every job
     git checkout HEAD -- pom.xml #gitlab CI also caches the pom from the preivous build, reset this to the correct pom 
     commit_time=$(git log -1 --format=%ct)
     mvn build-helper:parse-version versions:set -DnewVersion=\${parsedVersion.majorVersion}.\${parsedVersion.minorVersion}.\${parsedVersion.incrementalVersion}-$(date -d@$commit_time +%y%m%d%H%M%S)
     mvn package -U -P$release_env -Dmaven.test.skip=true
elif [ $ci_step == "release" ]
then mvn org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.version | grep '^[0-9]\.[0-9]\.[0-9]-[0-9]\{12\}$'
     mvn org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.name 2> /dev/null | grep -o '^[a-z].*$'
     mvn_version="$(mvn org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.version | grep '^[0-9]\.[0-9]\.[0-9]-[0-9]\{12\}$')"
     mvn_name="$(mvn org.apache.maven.plugins:maven-help-plugin:2.1.1:evaluate -Dexpression=project.name 2> /dev/null | grep -o '^[a-z].*$')"
     echo mvn_version:$mvn_version
     if [ $release_type == "docker" ]
     then if [ -z "$svc_name" ]
          then echo You must have CI_ALT_NAME defined in the .gitlab-ci.yml
               exit 1
          fi
          echo mvn_version $svc_name:$mvn_version
          echo docker_version $svc_name:$docker_version

          sudo docker build . \
                      -t $ecs_addr/$svc_name:$mvn_version \
                      -t $ecs_addr/$svc_name:$docker_version \
                      -t $ecs_addr/$svc_name:$mvn_version-$docker_version \
                      --build-arg JAR_NAME=${mvn_name}-${mvn_version}.jar \
                      --build-arg PROFILE=$release_env

	  sudo $(sudo /root/.local/bin/aws ecr get-login)
          sudo docker push $ecs_addr/$svc_name:$mvn_version
          sudo docker push $ecs_addr/$svc_name:$docker_version
          sudo docker push $ecs_addr/$svc_name:$mvn_version-$docker_version
          sudo kubectl config use-context $kube_context
          sudo kubectl config current-context
          sudo kubectl set image deploy/$svc_name \
                       $svc_name=$ecs_addr/$svc_name:$mvn_version
     elif [ $release_type == "maven" ]
     then mvn_url="libs-$release_env-local/"
          full_mvn_url="$mvn_url/$artifact_url/${mvn_name}/${mvn_version}"
          mvn_file_format="${mvn_name}-${mvn_version}"
          jfrog rt u target/$mvn_file_format.jar $full_mvn_url/
          jfrog rt u pom.xml $full_mvn_url/$mvn_file_format.pom
     else echo unknown release type $release_type
          exit 1
     fi
fi
