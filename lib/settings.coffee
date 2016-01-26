module.exports =
  scope: 'smalls'
  
  get: (param) ->
    atom.config.get("#{@scope}.#{param}")

  set: (param, value) ->
    atom.config.set("#{@scope}.#{param}", value)
