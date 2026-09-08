"use client";

import { FormEvent, useState } from "react";
import { useRouter, useSearchParams } from "next/navigation";
import { createClient } from "@/lib/supabase/client";

export default function LoginPage() {
  const router = useRouter();
  const searchParams = useSearchParams();
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [pending, setPending] = useState(false);

  async function submit(event: FormEvent<HTMLFormElement>) {
    event.preventDefault();
    setPending(true);
    setError(null);
    const { error: signInError } = await createClient().auth.signInWithPassword({ email, password });
    if (signInError) {
      setError("Sign-in failed. Check your credentials or contact an administrator.");
      setPending(false);
      return;
    }
    router.push(searchParams.get("next") || "/dashboard");
    router.refresh();
  }

  return <main className="auth-page"><section className="auth-card">
    <div className="brand"><span className="brand-mark">E</span><span>EUEE Content Studio</span></div>
    <p className="eyebrow" style={{ marginTop: 46 }}>Private authoring workspace</p>
    <h1>Review the source, preserve the truth.</h1>
    <p className="lede">Sign in to work on assigned EUEE projects. AI assistance is always kept separate from human decisions.</p>
    <form className="form" onSubmit={submit}>
      <label>Email<input type="email" value={email} onChange={(event) => setEmail(event.target.value)} required autoComplete="email" /></label>
      <label>Password<input type="password" value={password} onChange={(event) => setPassword(event.target.value)} required autoComplete="current-password" /></label>
      {error && <p className="error" role="alert">{error}</p>}
      <button className="button" type="submit" disabled={pending}>{pending ? "Signing in…" : "Sign in"}</button>
    </form>
  </section></main>;
}
