#!/bin/bash

hugo -D
git add .
git commit -m "$1"
git push origin main
cd public
git add .
git commit -m "$1"
git push origin main
