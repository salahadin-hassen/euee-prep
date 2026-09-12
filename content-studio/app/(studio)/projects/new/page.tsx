import Link from "next/link";
import { redirect } from "next/navigation";
import { createClient } from "@/lib/supabase/server";
import { canAccessAdminSurface, type AppRole } from "@/lib/auth/roles";
import { NewProjectForm } from "./new-project-form";

export default async function NewProjectPage() {
  const supabase = await createClient();
  const { data: { user } } = await supabase.auth.getUser();
  if (!user) redirect("/login");
  const { data: profile } = await supabase.from("profiles").select("role").eq("id", user.id).single();
  if (!profile || !canAccessAdminSurface(profile.role as AppRole)) redirect("/projects");

  return (
    <main className="content">
      <section className="hero">
        <div>
          <p className="eyebrow">Create project</p>
          <h1>New project</h1>
          <p className="lede">Create a new authoring project. You will be added as an admin member automatically.</p>
        </div>
        <Link className="button" href="/projects">Back to papers</Link>
      </section>
      <section className="panel"><NewProjectForm /></section>
    </main>
  );
}
