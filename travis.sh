#!/bin/bash

set -euo pipefail


function install {
  export MAVEN_OPTS="-Xmx1G -Xms128m"
  MAVEN_OPTIONS="-Dmaven.test.redirectTestOutputToFile=false -Dsurefire.useFile=false -DdisableXmlReport=true -B -e -V"

  INITIAL_VERSION='${project.version}'
  if [[ $INITIAL_VERSION =~ "-SNAPSHOT" ]]; then
    set_maven_build_version $TRAVIS_BUILD_NUMBER
  fi

  if [[ $INITIAL_VERSION =~ "-SNAPSHOT" ]]; then
    echo "======= Found SNAPSHOT version ======="
    # Do not deploy a SNAPSHOT version but the release version related to this build
    set_maven_build_version $TRAVIS_BUILD_NUMBER
  else
    echo "======= Found RELEASE version ======="
  fi

  if [ "$TRAVIS_BRANCH" == "master" ] && [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
    echo 'Analyse and trigger QA of master branch'

    # Fetch all commit history so that SonarQube has exact blame information
    # for issue auto-assignment
    # This command can fail with "fatal: --unshallow on a complete repository does not make sense"
    # if there are not enough commits in the Git repository (even if Travis executed git clone --depth 50).
    # For this reason errors are ignored with "|| true"
    git fetch --unshallow || true

    mvn org.jacoco:jacoco-maven-plugin:prepare-agent deploy sonar:sonar \
          $MAVEN_OPTIONS \
          -Pdeploy-sonarsource \
          -Dsonar.host.url=$SONAR_HOST_URL \
          -Dsonar.login=$SONAR_TOKEN \
          -Dsonar.projectVersion=$INITIAL_VERSION

  elif [[ "$TRAVIS_BRANCH" == "branch-"* ]] && [ "$TRAVIS_PULL_REQUEST" == "false" ]; then
    echo 'release branch: trigger QA, no analysis'

    mvn deploy \
        $MAVEN_OPTIONS \
        -Pdeploy-sonarsource

  elif [ "$TRAVIS_PULL_REQUEST" != "false" ] && [ -n "${GITHUB_TOKEN:-}" ]; then
    echo 'Internal pull request: trigger QA and analysis'

    mvn org.jacoco:jacoco-maven-plugin:prepare-agent deploy sonar:sonar \
        $MAVEN_OPTIONS \
        -Dsource.skip=true \
        -Pdeploy-sonarsource \
        -Dsonar.analysis.mode=issues \
        -Dsonar.github.pullRequest=$TRAVIS_PULL_REQUEST \
        -Dsonar.github.repository=$TRAVIS_REPO_SLUG \
        -Dsonar.github.oauth=$GITHUB_TOKEN \
        -Dsonar.host.url=$SONAR_HOST_URL \
        -Dsonar.login=$SONAR_TOKEN

  else
    echo 'Feature branch or external pull request: no QA, no analysis. Skip sources'

    mvn install \
        $MAVEN_OPTIONS \
        -Dsource.skip=true
  fi


}

mvn test
install
