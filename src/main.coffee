require('file?name=[name].[ext]!./index.html')
require('./main.sass')

Ractive = require('ractive')

width = 10
height = 7


grid = {
  sides: {
#    top: ([2, 3] for [1..width])
    top: [[0],[3],[3],[3],[0],[0],[0],[0],[0],[0]]
#    side: ([0] for [1..height])
    side: [[0],[3],[3],[3],[0],[0],[0]]
  }
  cells: ((0 for [0...width]) for [0...height])
}
ractive = new Ractive({
  el: '#container'
  template: '#template'
  magic: true
  data: {
    grid: grid
  }
  events: {
    tap: require('ractive-events-tap')
  }
})

ractive.on({
  tapped: (event, x, y) ->
    ractive.toggle("grid.cells[#{y}][#{x}]")
})

cellsToNumbers = (cells) ->
  numbers = []
  number = 0
  for cell in cells
    if cell
      number += 1
    else
      if number > 0
        numbers.push(number)
        number = 0
  if number > 0
    numbers.push(number)

  return if numbers.length > 0 then numbers else [0]

calculateSides = (grid) ->
  for y in [0...grid.cells.length]
    grid.sides.side[y] = cellsToNumbers(grid.cells[y])
  for x in [0...grid.cells[0].length]
    grid.sides.top[x] = cellsToNumbers((row[x] for row in grid.cells))
  return grid

numbersToCells = (numbers, cells) ->
  getOptions = (numbers, max, min = 0) ->
    if min > (max - numbers[0]) or not numbers?
      return []
    if numbers.length == 1
      return ([n] for n in [min..(max - numbers[0])])
    options = []
    for n in [min..(max - numbers[0])]
      if numbers.length == 1
        options.push([n])
      for option in getOptions(numbers.slice(1, numbers.length), max, n + 1 + numbers[0])
        options.push([n].concat(option))
    return options

  options = getOptions(numbers, cells.length)
  validOptions = []
  for option in options
    cellsOption = (2 for [0...cells.length])
    for x in [0...option.length]
      for n in [0...numbers[x]]
        cellsOption[option[x] + n] = 1

    fits = true
    for n in [0...cells.length]
      if cells[n] != 0 and cells[n] != cellsOption[n]
        fits = false

    if fits
      validOptions.push(cellsOption)

  for x in [0...cells.length]
    value = (option[x] for option in validOptions).reduce((a, b) -> if a == b then a else 0)
    if value
      cells[x] = value

  return cells

calculateCells = (grid) ->
  for y in [0...grid.cells]
    for x in [0...grid.cells[y]]
      grid.cells[y][x] = 0

  changed = true
  while changed
    changed = false

    for y in [0...grid.cells.length]
      cells = numbersToCells(grid.sides.side[y], grid.cells[y].slice())
      for x in [0...cells.length]
        if grid.cells[y][x] != cells[x]
          changed = true
          grid.cells[y][x] = cells[x]
    for x in [0...grid.cells[0].length]
      cells = numbersToCells(grid.sides.top[x], (row[x] for row in grid.cells).slice())
      for y in [0...cells.length]
        if grid.cells[y][x] != cells[y]
          changed = true
          grid.cells[y][x] = cells[y]

  return grid

#ractive.observe('grid.cells', (value, oldValue) ->
#  if oldValue?
#    ractive.set('grid', calculateSides(ractive.get('grid')))
#)
ractive.observe('grid.sides', () ->
  ractive.set('grid', calculateCells(ractive.get('grid')))
)