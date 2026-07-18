import type { PageLoad } from "./$types";
import { calendarSchema } from "$lib/schemas";
import { superValidate } from "sveltekit-superforms";
import { zod } from "$lib/superforms";
import { calendars, users } from "$lib/api";
import { redirect } from "@sveltejs/kit";

export const load: PageLoad = async ({ parent }) => {
  const parentData = await parent();
  const { activeCalendarId, publicKey } = parentData;
  if (!activeCalendarId) {
    redirect(307, "/");
  }
  const calendar = await calendars.findById(activeCalendarId);
  const user = await users.get(activeCalendarId, publicKey);
  const userRole = user!.role;
  const form = await superValidate(calendar, zod(calendarSchema));

  return {
    title: "edit calendar",
    form,
    userRole,
  };
};
