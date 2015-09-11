---
layout: post
title:  "Hibernate & java.util.Map"
date:   2015-09-11 12:00:00
categories: hibernate
---

Рассмотрим простую ситуацию. У нас есть некий отчет с таблицей, у которой фиксированный набор полей.
Представим в виде структуры классов (псевдокод на псевдогруви)

{% highlight groovy %}
class Report {
   Map<RowName, RowEntry> table
}
class RowEntry {
   String p1, p2
}
enum RowName {
   A,B,C,D
}
{% endhighlight %}

В базе мы хотим видеть такую структуру:

<pre>
select * from row_entry;
+---+------+------+------------+-----------+
| id| p1   | p2   | report_id  | table_key |
+---+------+------+------------+-----------+
| 1 | aaa  | aaaa | 1          | A         |
| 2 | bbb  | bbbb | 1          | B         |
+---+------+------+---+--------------------+
2 rows in set (0.00 sec)

select * from report;
+----+
| id |
+----+
| 1  |
+----+
</pre>

Маппинг аннотациями:

{% highlight java %}
@MappedSuperclass
@Data
@EqualsAndHashCode(of = {"id"})
public abstract class GenericEntity implements Serializable {
   @Id @GeneratedValue
   protected Long id;
}

@Entity
@Data
@EqualsAndHashCode(callSuper = true)
public class Report extends GenericEntity {
   @OneToMany(cascade = CascadeType.ALL)
   @JoinColumn(name = "report_id")
   @MapKeyEnumerated(EnumType.STRING)
   private Map<RowName, RowEntry> table = new LinkedHashMap();
}

@Entity
@Data
@EqualsAndHashCode(callSuper = true)
@NoArgsConstructor
@AllArgsConstructor
public class RowEntry extends GenericEntity implements Serializable {
   private String p1, p2;
}

public enum RowName {
   A,B,C,D
}
{% endhighlight %}

[Репозиторий с примером](https://github.com/d10xa/blog-examples/tree/master/hibernate/map-mapping-1)