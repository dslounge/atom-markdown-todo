utils = require '../lib/utils'

describe 'utils', ->
  describe 'elementSumArray', ->
    it 'adds up two arrays element-wise', ->
      a = [0, 1, 2]
      b = [1, 2, 3]
      testVal = utils.elementSumArray(a, b)
      expect(testVal).toEqual([1, 3, 5])
