import type { PageLoad } from "./$types";
import { events, spaces, resources, users } from "$lib/api";
import { eventSchema } from "$lib/schemas";
import { error } from "@sveltejs/kit";
import { superValidate } from "sveltekit-superforms";
import { zod } from "$lib/superforms";
import { db } from "$lib/db";
import { TimeSpanClass } from "$lib/timeSpan";

export const load: PageLoad = async ({ parent, url }) => {
  const eventId = url.searchParams.get("id");
  if (!eventId) {
    error(404, {
      message: "Event not found",
    });
  }

  const event = await events.findById(eventId);
  if (!event || !event.id) {
    error(404, {
      message: "Event not found",
    });
  }

  const { calendarId } = event;
  const currentSpace = event.spaceRequest?.space;
  const eventFields = {
    id: event.id,
    name: event.name,
    description: event.description,
    startDate: event.startDate,
    endDate: event.endDate,
    publicStartDate: event.publicStartDate ?? "",
    publicEndDate: event.publicEndDate ?? "",
    links: event.links,
    images: event.images,
  };
  const form = await superValidate(eventFields, zod(eventSchema));

  // return spaces and resources with availability within the calendar dates
  const activeCalendar = await db.calendars.get(calendarId!);
  const timeSpan = new TimeSpanClass({
    start: activeCalendar!.startDate!,
    end: activeCalendar!.endDate,
  });
  const spacesList = await spaces.findByTimeSpan(calendarId!, timeSpan);
  const resourcesList = await resources.findByTimeSpan(calendarId!, timeSpan);

  const parentData = await parent();
  const { activeCalendarId, publicKey } = parentData;
  const user = await users.get(activeCalendarId!, publicKey);
  const userRole = user!.role;

  return {
    title: "edit space",
    form,
    currentSpace,
    calendarId,
    spacesList,
    resourcesList,
    userRole,
  };
};
