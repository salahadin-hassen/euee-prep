"use client";

export default function ErrorPage({ reset }: { error: Error & { digest?: string }; reset: () => void }) {
  return <main className="auth-page"><section className="auth-card"><p className="eyebrow">Workspace error</p><h1>Could not load this view.</h1><p className="lede">The request failed before any content was changed.</p><button className="button" onClick={reset}>Try again</button></section></main>;
}
