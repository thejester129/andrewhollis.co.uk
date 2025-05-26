---
icon: fas fa-pencil
order: 3
layout: default
---

<div id="post-list" class="flex-grow-1 px-xl-1">
  {% assign page_category = 'blog' %}
  {% for post in site.posts %}
    {% if post.categories contains page_category %}
      {% include blogthumb.html %}
    {% endif %}
  {% endfor %}
</div>



