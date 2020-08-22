# LTN-data notes

- `train.schedule` is expensive
  - Split train iteration from station iteration
    - To do that we need to compile a list of all trains during station iteration, then go over those separately
- Spread deliveries processing over multiple ticks
- Spread all sorting logic over multiple ticks (n number of players per tick, and only one table per player per time)
  - Use `table.sort()` with a custom sort function, instead of the current dumb method
- Deepcopying the materials tables to each station is slow (line 104)
- `sort_stations` is slower than the rest of the sorting steps (probably because it's much bigger)
- Conditionally register on_tick (maybe)