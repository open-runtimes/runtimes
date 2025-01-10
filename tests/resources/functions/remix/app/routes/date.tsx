import { useLoaderData } from "@remix-run/react";

export async function loader() {
  const date = new Date().toISOString();
  return { date };
}

export default function Index() {
  const data = useLoaderData();
  const { date } = data;

  return (
    <p>[DATE_START]{date}[DATE_END]</p>
  );
}
