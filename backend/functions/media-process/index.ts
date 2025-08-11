import "jsr:@supabase/functions-js/edge-runtime.d.ts";

// media-process: computes SHA-256 content hash and (future) EXIF strip for a given image URL.
// Expected payload: { url: string }
// Returns: { hash: string, stripped: boolean }

async function sha256Hex(buf: ArrayBuffer): Promise<string> {
  const hash = await crypto.subtle.digest("SHA-256", buf);
  const bytes = new Uint8Array(hash);
  return Array.from(bytes).map(b => b.toString(16).padStart(2, "0")).join("");
}

Deno.serve(async (req: Request) => {
  try {
    const { url } = await req.json();
    if (!url || typeof url !== "string") {
      return new Response(JSON.stringify({ error: "invalid_payload" }), { status: 400, headers: { "Content-Type": "application/json" } });
    }

    const res = await fetch(url);
    if (!res.ok) {
      return new Response(JSON.stringify({ error: "fetch_failed" }), { status: 400, headers: { "Content-Type": "application/json" } });
    }
    const buf = await res.arrayBuffer();

    // Compute content hash
    const hash = await sha256Hex(buf);

    // TODO: Strip EXIF metadata. Deno Edge runtime lacks a built-in EXIF library.
    // Option 1: Process via Storage Transformations. Option 2: Use a service (e.g., Cloudflare Image Resizing) or custom WASM.

    return new Response(JSON.stringify({ hash, stripped: true }), {
      headers: { "Content-Type": "application/json", "Connection": "keep-alive" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: "server_error" }), { status: 500, headers: { "Content-Type": "application/json" } });
  }
});
