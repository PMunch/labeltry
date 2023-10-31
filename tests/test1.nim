# This is just an example to get you started. You may wish to put all of your
# tests into a single file, or separate them into multiple `test1`, `test2`
# etc. files (better names are recommended, just make sure the name starts with
# the letter 't').
#
# To run these tests, simply execute `nimble test`.

import unittest

import labeltry
test "Simple exception":
  labeledTry:
    label(OtherErr):
      raise newException(ValueError, "Error")
  except:
    check getLabel() == OtherErr
  finally:
    check getLabel() == OtherErr
test "Multiple exceptions":
  labeledTry:
    label(FirstErr):
      raise newException(ValueError, "Error")
    label(OtherErr):
      raise newException(ValueError, "Error")
  except:
    check getLabel() == FirstErr
  finally:
    check getLabel() == FirstErr

import strutils
test "Pipe label":
  labeledTry:
    let num = parseInt("100t") |> ParseErr
    echo num
  except:
    check getLabel() == ParseErr
  finally:
    check getLabel() == ParseErr
test "Repeated label":
  labeledTry:
    let num = parseInt("100t") |> ParseErr
    echo num
    let num2 = parseInt("100t") |> ParseErr
    echo num2
  except:
    check getLabel() == ParseErr
    check Label.low == NoLabel
    check Label.high == ParseErr
    check Label.high.int == 1
  finally:
    check getLabel() == ParseErr
    check Label.low == NoLabel
    check Label.high == ParseErr
    check Label.high.int == 1
