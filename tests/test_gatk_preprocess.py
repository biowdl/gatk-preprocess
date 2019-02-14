from pathlib import Path

import pysam
import pytest


@pytest.mark.workflow("recalibrated_bam")
def test_recalibrated_bam(workflow_dir):
    bam_path = workflow_dir / Path("test-output") / Path("test.bam")
    bam_file = pysam.AlignmentFile(str(bam_path), "rb")
    assert True