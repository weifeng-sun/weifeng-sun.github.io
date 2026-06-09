---
layout: page
permalink: /publications/
title: Publications
description: Journal articles and conference papers
nav: true
nav_order: 2
---

<p class="publication-note">
  {{ site.data.publication_stats.all.total }} marked ·
  † first author {{ site.data.publication_stats.all.first }} ·
  ✰ co-first author {{ site.data.publication_stats.all.cofirst }} ·
  * corresponding author {{ site.data.publication_stats.all.corresponding }}
</p>

<div class="publications">

{% bibliography %}

</div>
