#!/bin/bash
docker build -f Dockerfile.base . --tag ${TRAVIS_REPO_SLUG}:base
docker build -f Dockerfile . --tag ${TRAVIS_REPO_SLUG}:${TRAVIS_BRANCH}
