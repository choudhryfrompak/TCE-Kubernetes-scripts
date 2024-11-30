#!/bin/bash
ray start --head --port=6379 --block && tail -f /dev/null
