---
icon: fas fa-code
order: 2
layout: default
---

<div id="post-list" class="flex-grow-1 px-xl-1">
  {% assign page_category = 'dev' %}
  {% for post in site.posts %}
    {% if post.categories contains page_category %}
      {% include blogthumb.html %}
    {% endif %}
  {% endfor %}
</div>

