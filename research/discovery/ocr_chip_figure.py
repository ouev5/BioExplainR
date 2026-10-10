"""OCR saved primary figure; retain image/OCR provenance, not a manual visual review."""
import hashlib
import json
from pathlib import Path
import os
import subprocess
from PIL import Image


def main():
    out=Path('research/results/discovery_chip_v1')
    source=out/'Sasse_2017_Figure3_verified.jpg'
    image=Image.open(source);image.resize((image.width*5,image.height*5)).save(out/'Sasse_2017_Figure3_ocr.png')
    env=os.environ.copy();env['LD_LIBRARY_PATH']='/tmp/opencode/tesseract/usr/lib/x86_64-linux-gnu';env['TESSDATA_PREFIX']='/tmp/opencode/tesseract/usr/share/tesseract-ocr/5/tessdata'
    result=subprocess.run(['/tmp/opencode/tesseract/usr/bin/tesseract',str(out/'Sasse_2017_Figure3_ocr.png'),'stdout','--psm','11'],env=env,capture_output=True,text=True,check=True)
    (out/'Sasse_2017_Figure3_ocr.txt').write_text(result.stdout)
    (out/'figure_ocr_provenance.json').write_text(json.dumps(dict(image_sha256=hashlib.file_digest(source.open('rb'),'sha256').hexdigest(),
        engine='Tesseract 5.3.4; sparse text psm11; 5x resize',scope='OCR only, no human/manual visual confirmation',stderr=result.stderr),indent=2)+'\n')
    print(result.stdout)


if __name__=='__main__':main()
