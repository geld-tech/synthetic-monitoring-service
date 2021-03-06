#!/usr/bin/env python
# -*- coding: utf-8 -*-
"""
    ServiceStatus Class

    Polls service metrics on availability and latency

"""
from __future__ import absolute_import, unicode_literals

import logging
import logging.handlers
import socket
import time

try:                 # for Python 3
    from urllib.request import urlopen, Request
except ImportError:  # for Python 2
    from urllib2 import urlopen, Request


class ServiceStatus:
    def __init__(self, url="https://www.geld.tech/"):
        logging.basicConfig(format='[%(asctime)-15s] [%(threadName)s] %(levelname)s %(message)s', level=logging.INFO)
        self.logger = logging.getLogger('root')
        self.hostname = self._get_server_hostname()
        self._data = {}
        self.url = url
        self.collect_metrics(list())

    def get(self):
        return self._data

    def poll_metrics(self, services):
        self.collect_metrics(services)
        return self._data

    def collect_metrics(self, services):
        self._data = self._get_metrics(services)

    def is_reachable(self, url, timeout=5):
        try:
            req = Request(url)
            response = urlopen(req, timeout=timeout)
            response.close()
            return True
        except Exception as e:
            self.logger.debug('Error reaching service (%s): %s' % (url, e))
            return False

    def measure_latency(self, url):
        try:
            req = urlopen(url)
            start = time.time()
            page = req.read()
            end = time.time()
            req.close()
            del page  # Avoids linter issue
            return round((end - start) * 1000, 2)  # Time interval in milliseconds
        except Exception as e:
            self.logger.debug('Error retrieving latency status (%s): %s' % (url, e))
            return False

    def get_metrics(self, url):
        try:
            data = {}
            data['reachable'] = False
            if self.is_reachable(url):
                latency = self.measure_latency(url)
                if latency:
                    data['latency'] = latency
                    data['reachable'] = True
            return data
        except Exception as e:
            self.logger.error('Error retrieving service metrics (%s): %s' % (url, e))
            return {}

    def _get_metrics(self, services):
        try:
            data = {}
            for service in services:
                name = service.get('name')
                url = service.get('url')
                data[name] = self.get_metrics(url)
            return data
        except Exception as e:
            self.logger.error('Error retrieving service status (%s): %s' % (services, e))
            return {}

    def _get_server_hostname(self):
        try:
            hostname = socket.gethostname()
            return hostname
        except Exception as e:
            self.logger.error('Error reading hostname: %s' % e)
            return False

    def get_server_hostname(self):
        return self.hostname
