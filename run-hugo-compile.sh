#!/bin/bash
cd /usr/share/blog && python3.6 -m venv venv && source venv/bin/activate && pip install -r ./.pandoc/requirements.txt && cp -purv .pandoc ~/ && hugo
