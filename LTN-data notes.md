# LTN-data notes

- `train.schedule` is expensive
  - Split train iteration from station iteration
- Spread deliveries processing over multiple ticks
- Spread all sorting logic over multiple ticks (n number of players per tick, and only one table per player per time)
  - Use `table.sort()` with a custom sort function, instead of the current dumb method