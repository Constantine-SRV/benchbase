/*
 * Copyright 2020 by OLTPBenchmark Project
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 *
 */

package com.oltpbenchmark.benchmarks.chbenchmark.queries;

import com.oltpbenchmark.api.SQLStmt;
import java.sql.Connection;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

public class Q15 extends GenericQuery {

  // Сохраняем оригинальные поля для совместимости с фреймворком
  public final SQLStmt createview_stmt =
      new SQLStmt(
          "CREATE view revenue0 (supplier_no, total_revenue) AS "
              + "SELECT "
              + "mod((s_w_id * s_i_id),10000) as supplier_no, "
              + "sum(ol_amount) as total_revenue "
              + "FROM "
              + "order_line, stock "
              + "WHERE "
              + "ol_i_id = s_i_id "
              + "AND ol_supply_w_id = s_w_id "
              + "AND ol_delivery_d >= '2007-01-02 00:00:00.000000' "
              + "GROUP BY "
              + "supplier_no");

  public final SQLStmt query_stmt =
      new SQLStmt(
          "SELECT su_suppkey, "
              + "su_name, "
              + "su_address, "
              + "su_phone, "
              + "total_revenue "
              + "FROM supplier, revenue0 "
              + "WHERE su_suppkey = supplier_no "
              + "AND total_revenue = (select max(total_revenue) from revenue0) "
              + "ORDER BY su_suppkey");

  public final SQLStmt dropview_stmt = new SQLStmt("DROP VIEW revenue0");

  protected SQLStmt get_query() {
    return query_stmt;
  }

  @Override
  public void run(Connection conn) throws SQLException {
    // ЕДИНСТВЕННОЕ ИЗМЕНЕНИЕ: используем уникальное имя VIEW для каждого потока
    String viewName = "revenue_" + Thread.currentThread().threadId();
    
    // Динамически создаём SQL с уникальным именем VIEW
    String createSQL =
        "CREATE view " + viewName + " (supplier_no, total_revenue) AS "
            + "SELECT "
            + "mod((s_w_id * s_i_id),10000) as supplier_no, "
            + "sum(ol_amount) as total_revenue "
            + "FROM "
            + "order_line, stock "
            + "WHERE "
            + "ol_i_id = s_i_id "
            + "AND ol_supply_w_id = s_w_id "
            + "AND ol_delivery_d >= '2007-01-02 00:00:00.000000' "
            + "GROUP BY "
            + "supplier_no";

    String querySQL =
        "SELECT su_suppkey, "
            + "su_name, "
            + "su_address, "
            + "su_phone, "
            + "total_revenue "
            + "FROM supplier, " + viewName + " "
            + "WHERE su_suppkey = supplier_no "
            + "AND total_revenue = (select max(total_revenue) from " + viewName + ") "
            + "ORDER BY su_suppkey";

    String dropSQL = "DROP VIEW " + viewName;

    // Выполняем как в оригинале, но с уникальным именем VIEW
    try (Statement stmt = conn.createStatement()) {
      try {
        stmt.executeUpdate(createSQL);
        try (ResultSet rs = stmt.executeQuery(querySQL)) {
          while (rs.next()) {
            // Проходим результаты
          }
        }
      } finally {
        stmt.executeUpdate(dropSQL);
      }
    }
  }
}
