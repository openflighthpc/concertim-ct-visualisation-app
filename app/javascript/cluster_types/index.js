document.addEventListener("DOMContentLoaded", function() {
  const teamSelect = document.querySelector("#choose_cluster_team");
  const cards = document.querySelectorAll(".cluster-type-card");

  if(teamSelect && !teamSelect.disabled && cards.length > 0) {
    teamSelect.addEventListener("change", function(event) {
      let selectedTeamId = event.target.value;

      cards.forEach(function(link) {
        link.href = `${link.dataset.baseTargetUrl}?team_id=${selectedTeamId}`;
        link.classList.remove("disabled-cluster-type-card");
        link.title = "";
      });
    });
  }
});