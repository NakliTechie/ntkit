# Queries for /traces-nt

Run each with `duckdb -readonly "$TRACELENS_HOME/tracelens.duckdb" -c "<sql>"`. Replace `<since>` with
the date (`'2026-09-01'`), `<project>` with a quoted name or the literal `NULL`, and `<signal>` likewise.
Tables and columns are documented in tracelens `docs/formats.md`; the rules in `docs/signals.md`.

## 1. Weekly rate per signal (the measure baseline)

```sql
SELECT date_trunc('week', ts)::DATE AS week, signal, count(*) AS rows, count(DISTINCT file) AS sessions
FROM signals
WHERE ts >= <since> AND (<project> IS NULL OR project = <project>) AND (<signal> IS NULL OR signal = <signal>)
GROUP BY ALL ORDER BY week, signal;
```

## 2. Clusters inside one signal

`detail` starts with the tool, the waiting time, the reserved word or the human's words, so its
first words are a usable cluster key. Read the top rows, then refine the key by hand.

```sql
SELECT signal, project, regexp_extract(detail, '^(\S+(\s+\S+){0,2})', 1) AS key,
       count(*) AS rows, count(DISTINCT file) AS sessions,
       min(ts)::DATE AS first, max(ts)::DATE AS last,
       arg_min(file || ':' || line, ts) AS first_cite, arg_max(file || ':' || line, ts) AS last_cite
FROM signals
WHERE ts >= <since> AND (<project> IS NULL OR project = <project>) AND (<signal> IS NULL OR signal = <signal>)
GROUP BY ALL HAVING count(*) >= 3 OR count(DISTINCT file) >= 2
ORDER BY rows * sessions DESC LIMIT 20;
```

## 3. Failing commands behind `repeated_failure`

```sql
SELECT c.tool, left(regexp_replace(coalesce(c.command, c.input), '\s+', ' ', 'g'), 120) AS shape,
       left(regexp_replace(c.error_text, '\s+', ' ', 'g'), 120) AS error,
       count(*) AS fails, count(DISTINCT c.file) AS sessions, any_value(c.file || ':' || c.line) AS cite
FROM tool_calls c JOIN sessions s USING (file)
WHERE c.is_error AND c.ts >= <since> AND (<project> IS NULL OR s.project = <project>)
GROUP BY ALL ORDER BY fails DESC LIMIT 20;
```

## 4. Scheduled-task attribution (stalls and failures by task)

A scheduled run's first human-role turn starts with `<scheduled-task name="…">`.

```sql
WITH task AS (
  SELECT file, any_value(regexp_extract(text, 'scheduled-task name="([^"]+)"', 1)) AS task
  FROM turns WHERE role = 'user' AND starts_with(text, '<scheduled-task') GROUP BY file)
SELECT coalesce(t.task, '(interactive)') AS task, g.signal, count(*) AS rows, count(DISTINCT g.file) AS sessions,
       any_value(g.file || ':' || g.line) AS cite
FROM signals g LEFT JOIN task t USING (file)
WHERE g.ts >= <since> AND (<signal> IS NULL OR g.signal = <signal>)
GROUP BY ALL ORDER BY rows DESC LIMIT 20;
```

## 5. One session in context (before you read raw lines)

```sql
SELECT line, role, kind, left(regexp_replace(text, '\s+', ' ', 'g'), 160) AS text
FROM turns WHERE file = '<file>' AND line BETWEEN <line> - 20 AND <line> + 5 ORDER BY line;
```

## 6. Did an earlier fix work?

Pick the finding's `Measure:` filter and compare the weeks before and after the fix landed.

```sql
SELECT ts >= <fix_date> AS after_fix, count(*) AS rows,
       count(*) / greatest(1, count(DISTINCT date_trunc('week', ts))) AS rows_per_week
FROM signals WHERE <measure filter> GROUP BY 1;
```
