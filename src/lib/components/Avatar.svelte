<!-- 
 @component
 Avatar displayed in the header of the app.
 
 Dynamically changes between 3 states based on number of connected peers:
 - Sad: Bad network health
 - Ok: Ok network health
 - Happy: Good network health
  -->

<script lang="ts">
  type Health = "sad" | "ok" | "happy";

  let kittyHealth: Health = $state("ok");

  const avatar: Record<Health, { src: string; alt: string }> = {
    sad: {
      src: "/images/toolkitty-avatar-sad.png",
      alt: "kitten sleeping next to toolkit box",
    },
    ok: {
      src: "/images/toolkitty-avatar-ok.png",
      alt: "kitten holding toolkit box",
    },
    happy: {
      src: "/images/toolkitty-avatar-happy.png",
      alt: "happy kitten sitting inside toolkit box",
    },
  };

  // TODO: get network status from backend and update avatar health state
</script>

<div class="w-10 h-full mx-auto">
  <img src={avatar[kittyHealth].src} alt={avatar[kittyHealth].alt} />
</div>
