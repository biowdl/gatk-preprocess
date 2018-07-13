/*
 * Copyright (c) 2018 Biowdl
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy of
 * this software and associated documentation files (the "Software"), to deal in
 * the Software without restriction, including without limitation the rights to
 * use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
 * the Software, and to permit persons to whom the Software is furnished to do so,
 * subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
 * FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
 * COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
 * IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
 * CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

package biowdl.test

import scala.collection.JavaConverters._

import htsjdk.samtools.{SamReader, SamReaderFactory}
import nl.biopet.utils.biowdl.PipelineSuccess
import org.testng.annotations.Test

trait GatkPreprocessSuccess extends GatkPreprocess with PipelineSuccess {
  addMustHaveFile(outputFile)
  addMustHaveFile(s"${outputFile.getName}".stripSuffix(".bam") + ".bai")

  @Test
  def testPrograms(): Unit = {
    val bamReader: SamReader = SamReaderFactory.makeDefault().open(outputFile)
    val programs: List[String] =
      bamReader.getFileHeader.getProgramRecords.asScala.map(_.getProgramName).toList

    programs should contain "GATK ApplyBQSR"

    if (splitSplicedReads) {
      programs should contain("GATK SplitNCigarReads")
    } else {
      programs should not contain "GATK SplitNCigarReads"
    }
  }
}
