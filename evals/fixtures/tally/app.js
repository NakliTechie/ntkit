// Tally: counters in localStorage. window.tally is the agent face (seed, list).
const KEY = "tally.v1";
const today = () => new Date().toLocaleDateString("en-CA"); // local YYYY-MM-DD
const load = () => JSON.parse(localStorage.getItem(KEY) || "[]");
const save = (cs) => localStorage.setItem(KEY, JSON.stringify(cs));

function render(bumped) {
  const cs = load(), ul = document.getElementById("counters");
  ul.innerHTML = "";
  document.getElementById("empty").hidden = cs.length > 0;
  cs.forEach((c, i) => {
    const li = document.createElement("li");
    li.className = "counter" + (i === bumped ? " bump" : "");
    const n = c.days[today()] || 0;
    li.innerHTML = `<span class="name"></span><span class="today">${n} today</span>
      <span class="total">${c.count}</span><button>+1</button>`;
    li.querySelector(".name").textContent = c.name;
    const btn = li.querySelector("button");
    btn.setAttribute("aria-label", `Add one to ${c.name}`);
    btn.onclick = () => bump(i);
    ul.appendChild(li);
  });
}

function bump(i) {
  const cs = load();
  cs[i].count += 1;
  cs[i].days[today()] = (cs[i].days[today()] || 0) + 1;
  save(cs); render(i);
}

document.getElementById("add").onsubmit = (e) => {
  e.preventDefault();
  const name = document.getElementById("name").value.trim();
  if (!name) return;
  save([...load(), { name, count: 0, days: {} }]);
  e.target.reset(); render();
};

document.getElementById("export").onclick = () => {
  const cell = (v) => `"${String(v).replace(/"/g, '""')}"`;
  const rows = [["name", "total", "today"], ...load().map((c) => [c.name, c.count, c.days[today()] || 0])];
  const a = document.createElement("a");
  a.href = URL.createObjectURL(new Blob([rows.map((r) => r.map(cell).join(",")).join("\n")], { type: "text/csv" }));
  a.download = "tally.csv"; a.click();
};

window.tally = {
  // Replaces every counter, so it refuses when counters exist unless told to replace.
  seed(list, { replace = false } = {}) {
    if (load().length && !replace) throw new Error("tally has counters; pass { replace: true } to overwrite");
    save(list.map((c) => ({ name: String(c.name), count: c.count || 0, days: { [today()]: c.today || 0 } })));
    render();
  },
  list: () => load(),
};
render();
