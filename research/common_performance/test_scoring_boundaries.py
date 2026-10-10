"""Meaningful scoring-denominator/parser probes; no model calls or gold tuning."""
import json
from pathlib import Path
import subprocess
import unittest
from audit_benchmark import parse


class ScoringTests(unittest.TestCase):
    def test_no_repaired_or_ambiguous_answers(self):
        cases=[('{"n_features":2}',False,{'n_features':2}),
            ('```json\n{"n_features":2}\n```',False,{'n_features':2}),
            ('{"n_features":2,"n_features":3}',False,{}),
            ('{"n_features":2.0}',False,{}),
            ('{"n_features":true}',False,{}),
            ('{"n_features":-1}',False,{}),
            ('Answer: {"n_features":2}',False,{}),
            ('{"n_features":2}',True,{}),
            ('{"n_features":2,"n_up":null}',False,{'n_features':2})]
        for text,truncated,expected in cases:self.assertEqual(parse(text,truncated),expected)
        code='''fields <- c("n_features","n_significant","n_up","n_down","n_na_padj")
e <- parse("research/common_performance/worker.R")
i <- which(vapply(e,function(x) is.call(x)&&identical(x[[1]],as.name("<-"))&&identical(x[[2]],as.name("parse_answer")),logical(1)))
stopifnot(length(i)==1); eval(e[[i]])
cases <- jsonlite::fromJSON(Sys.getenv("SCORING_CASES"),simplifyVector=FALSE)
for(c in cases) cat(as.character(jsonlite::toJSON(parse_answer(c[[1]],c[[2]]),auto_unbox=TRUE)),"\\n")
'''
        import os
        env=os.environ.copy();env['SCORING_CASES']=json.dumps(cases)
        z=subprocess.run(['Rscript','--vanilla','-e',code],env=env,capture_output=True,text=True,check=True)
        for line,case in zip(z.stdout.splitlines(),cases):self.assertEqual(json.loads(line) or {},case[2])

    def test_failure_remains_in_total_target_denominator(self):
        answers=[parse('{"n_features":2}',False),parse('',False),parse('{"n_features":2}',True)]
        self.assertEqual(sum(a.get('n_features')==2 for a in answers),1)
        self.assertEqual(len(answers)*5,15)


if __name__=='__main__':unittest.main()
