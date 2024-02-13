document.addEventListener("DOMContentLoaded", function() {
  const teamSelect = document.querySelector("#choose_cluster_team");
  const typeLinks = document.querySelectorAll(".cluster-type-link");

  if(teamSelect && !teamSelect.disabled && typeLinks.length > 0) {
    teamSelect.addEventListener("change", function(event) {
      let selectedTeamId = event.target.value;

      typeLinks.forEach(function(link) {
        link.href = `${link.dataset.baseTargetUrl}?team_id=${selectedTeamId}`;
        link.classList.remove("disabled-cluster-link");
        link.title = "";
      });
    });
  }
});
