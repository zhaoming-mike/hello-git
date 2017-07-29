#!/bin/bash
echo 'mike content:'$1 | git hash-object -w --stdin
