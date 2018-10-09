#!/bin/bash
docker build -f Dockerfile . --tag ${TRAVIS_REPO_SLUG}:${TRAVIS_BRANCH}
