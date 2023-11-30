#! /usr/bin/env sh 

zip create_auth_challenge.zip create_auth_challenge.js
zip define_auth_challenge.zip define_auth_challenge.js
npm install
zip -r verify_auth_challenge_response.zip verify_auth_challenge_response.js node_modules/*
