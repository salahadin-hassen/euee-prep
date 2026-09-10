import unittest

from worker_protocol import PROTOCOL_VERSION, WorkerJobDescriptor, WorkerProtocolError, descriptor_from_parts


JOB = "11111111-1111-4111-8111-111111111111"
PROJECT = "22222222-2222-4222-8222-222222222222"
DOCUMENT = "33333333-3333-4333-8333-333333333333"


class WorkerProtocolTests(unittest.TestCase):
    def test_valid_descriptor_round_trips_deterministically(self):
        descriptor = descriptor_from_parts(JOB, PROJECT, DOCUMENT, [4, 1, 3], "pipeline-test")
        self.assertEqual(descriptor.to_dict()["requested_pages"], [1, 3, 4])
        self.assertEqual(WorkerJobDescriptor.from_dict(descriptor.to_dict()), descriptor)

    def test_missing_fields_are_rejected(self):
        with self.assertRaises(WorkerProtocolError):
            WorkerJobDescriptor.from_dict({"protocol_version": PROTOCOL_VERSION})

    def test_invalid_pages_are_rejected(self):
        value = descriptor_from_parts(JOB, PROJECT, DOCUMENT, [1], "pipeline-test").to_dict()
        value["requested_pages"] = [1, 1]
        with self.assertRaises(WorkerProtocolError):
            WorkerJobDescriptor.from_dict(value)

    def test_unsupported_protocol_is_rejected(self):
        value = descriptor_from_parts(JOB, PROJECT, DOCUMENT, [1], "pipeline-test").to_dict()
        value["protocol_version"] = "99"
        with self.assertRaises(WorkerProtocolError):
            WorkerJobDescriptor.from_dict(value)

    def test_malformed_identifiers_are_rejected(self):
        value = descriptor_from_parts(JOB, PROJECT, DOCUMENT, [1], "pipeline-test").to_dict()
        value["job_id"] = "not-a-uuid"
        with self.assertRaises(WorkerProtocolError):
            WorkerJobDescriptor.from_dict(value)

    def test_unexpected_fields_are_rejected(self):
        value = descriptor_from_parts(JOB, PROJECT, DOCUMENT, [1], "pipeline-test").to_dict()
        value["signed_url"] = "must-not-be-in-the-protocol"
        with self.assertRaises(WorkerProtocolError):
            WorkerJobDescriptor.from_dict(value)


if __name__ == "__main__":
    unittest.main()
