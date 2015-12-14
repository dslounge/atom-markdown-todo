_ = require 'lodash'
module.exports =
  elementSumArray: (a, b) ->
    _.sum(x) for x in _.zip(a, b)
