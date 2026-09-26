# Tally

**Count anything, offline. One static page, no account, your counts stay in your browser.**

## Run

```bash
python3 -m http.server 8000
```

Open http://127.0.0.1:8000/ and press **Open Tally**.

## Use something else if

You need counts shared between people or devices. Tally keeps everything in this browser's `localStorage`; try a spreadsheet instead.

## How it works

1. Name a counter (cups of coffee, push-ups, bugs fixed).
2. Tap **+1** each time it happens.
3. Read the running total and today's count; **Export CSV** saves every counter.

## For agents

`window.tally.seed([{ name, count, today }])` loads counters without clicking. It refuses when counters exist; `seed(list, { replace: true })` overwrites them. `window.tally.list()` returns them.

## License

MIT. See [LICENSE](LICENSE).
