const greet = (name: string): string => `hello, ${name}`;
console.log(greet("andromeda"));

const data = { runtime: "andromeda", ok: true };
const parsed = JSON.parse(JSON.stringify(data));
if (parsed.runtime !== "andromeda") throw new Error("JSON round-trip failed");

const id = crypto.randomUUID();
if (id.length !== 36) throw new Error(`bad UUID: ${id}`);

const encoded = btoa("nix");
if (atob(encoded) !== "nix") throw new Error("base64 round-trip failed");

console.log("smoke test passed");
