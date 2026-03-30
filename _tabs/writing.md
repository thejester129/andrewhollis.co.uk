---
icon: fas fa-envelope
order: 2
layout: default
---

## Writing

<div id="post-list" class="flex-grow-1 px-xl-1">
  {% assign page_category = 'writing' %}
  {% for post in site.posts %}
    {% if post.categories contains page_category %}
      {% include writingthumb.html %}
    {% endif %}
  {% endfor %}
</div>

## Translations

<div id="post-list" class="flex-grow-1 px-xl-1">
  {% assign page_category = 'translations' %}
  {% for post in site.posts %}
    {% if post.categories contains page_category %}
      {% include writingthumb.html %}
    {% endif %}
  {% endfor %}
</div>
