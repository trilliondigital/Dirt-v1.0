import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "jsr:@supabase/supabase-js@2";

interface CreateBody {
  content: string;
  flag: "red" | "green";
  tags?: string[];
  anonymous?: boolean;
}

Deno.serve(async (req: Request) => {
  try {
    const body = (await req.json()) as CreateBody;
    const content = (body.content || "").trim();
    if (!content || content.length > 500) {
      return new Response(JSON.stringify({ error: "Content must be 1–500 chars" }), { status: 400 });
    }
    if (body.flag !== "red" && body.flag !== "green") {
      return new Response(JSON.stringify({ error: "Flag must be red or green" }), { status: 422 });
    }

    const supabase = createClient(
      Deno.env.get("SUPABASE_URL")!,
      Deno.env.get("SUPABASE_ANON_KEY")!,
      {
        global: { headers: { Authorization: req.headers.get("Authorization") ?? "" } },
      },
    );

    const { data: userRes, error: userErr } = await supabase.auth.getUser();
    if (userErr || !userRes.user) {
      return new Response(JSON.stringify({ error: "Unauthorized" }), { status: 401 });
    }
    const userId = userRes.user.id;

    // Persist post; DB has no flag column, so we include the flag as a tag for now
    const tags = Array.isArray(body.tags) ? body.tags.slice(0) : [];
    tags.push(body.flag === "red" ? "red flag" : "green flag");

    const { data: inserted, error: insErr } = await supabase
      .from("posts")
      .insert({
        user_id: userId,
        content,
        tags,
        has_media: false,
        blur_default: true,
      })
      .select("id, created_at")
      .single();

    if (insErr || !inserted) {
      return new Response(JSON.stringify({ error: insErr?.message ?? "Insert failed" }), { status: 500 });
    }

    // Mentions extraction (plain text usernames like @name)
    const mentions = [...content.matchAll(/@([A-Za-z0-9_]+)/g)].map((m) => m[1]).slice(0, 25);
    if (mentions.length > 0) {
      const rows = mentions.map((m) => ({ post_id: inserted.id, mentioned: m }));
      // Ignore failure; non-fatal
      await supabase.from("mentions").insert(rows);
    }

    return new Response(JSON.stringify({ id: inserted.id, createdAt: inserted.created_at }), {
      headers: { "Content-Type": "application/json" },
    });
  } catch (e) {
    return new Response(JSON.stringify({ error: String(e) }), { status: 500 });
  }
});
