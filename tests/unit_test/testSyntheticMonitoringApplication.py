from __future__ import absolute_import, unicode_literals

import os
import sys
sys.path.append(os.path.dirname(os.path.abspath(__file__))+'/../../sources/server')
import unittest
import mock

from application import evaluate_data

class TestSyntheticMonitoringApplication(unittest.TestCase):
    """TestSyntheticMonitoringApplication Unit Tests"""

    def setUp(self):
        """Initialisation"""
        pass

    def tearDown(self):
        """Cleaning-up resources used"""
        pass

    def test_evaluate_data(self):
        """application.evaluate_data()"""
        # Test with a Bytes input like Flask's request.data
        data1 = b'{"password":"123456"}'
        evaluated_data = evaluate_data(data1)
        self.assertIsInstance(evaluated_data, dict)
        self.assertEqual(evaluated_data, {'password': '123456'})
        self.assertIsInstance(evaluated_data['password'], str)
        self.assertEqual(evaluated_data['password'], '123456')
        # Test with a String input
        data2 = '{"password":"123456"}'
        evaluated_data = evaluate_data(data2)
        self.assertIsInstance(evaluated_data, dict)
        self.assertEqual(evaluated_data, {'password': '123456'})
        self.assertIsInstance(evaluated_data['password'], str)
        self.assertEqual(evaluated_data['password'], '123456')

if __name__ == '__main__':
    unittest.main()
