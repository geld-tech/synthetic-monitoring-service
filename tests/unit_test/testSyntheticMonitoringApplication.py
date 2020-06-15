from __future__ import absolute_import, unicode_literals

import os
import sys
sys.path.append(os.path.dirname(os.path.abspath(__file__))+'/../../sources/server/')
import unittest
import mock

from application import set_password


class TestSyntheticMonitoringApplication(unittest.TestCase):
    """TestSyntheticMonitoringApplication Unit Tests"""

    def test_init(self):
        """Instatiation"""
        #nginx_status = Nginx()
        pass

    def test_set_password(self):
        """application.set_password()"""
        data = b'{"password":"123456"}'
        with mock.patch("flask.request.data", data):
            set_password()

    def test_get(self):
        """Data getter"""
        #nginx_status = NginxStatus()
        #self.assertEqual(dict, type(nginx_status.get()))
        # Empty directories evaluate to False in Python
        #self.assertNotEqual(False, nginx_status.get())

    def test_poll_metrics(self):
        """Poll Metrics"""
        #nginx_status = NginxStatus()
        #self.assertEqual(dict, type(nginx_status.poll_metrics()))
        # Empty directories evaluate to False in Python
        #self.assertNotEqual(False, nginx_status.poll_metrics())

    def test_collect_metrics(self):
        """Collect Metrics"""
        #nginx_status = NginxStatus()
        #nginx_status.collect_metrics()
        #self.assertEqual(dict, type(nginx_status.get()))
        # Empty directories evaluate to False in Python
        #self.assertNotEqual(False, nginx_status.get())


if __name__ == '__main__':
    unittest.main()
