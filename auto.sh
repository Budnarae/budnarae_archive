#!/bin/bash

hugo -D
git add .
git commit
git push origin main
cd public
git add .
git commit
git push origin main
