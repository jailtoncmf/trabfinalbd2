package br.com.bda.portalestudantil;


import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.sql.*;
import java.util.Scanner;

public class PortalEstudantil {
    private static final String URL = "jdbc:postgresql://localhost:5432/trabfinalbd2";
    private static final String USER = "postgres";
    private static final String PASSWORD = "fifa16";

    public static void main(String[] args) {
        try (Connection conn = DriverManager.getConnection(URL, USER, PASSWORD)) {
            System.out.println("Conexão com o banco de dados estabelecida!");
            Scanner scanner = new Scanner(System.in);

            while (true) {
                System.out.println("\n--- Menu ---");
                System.out.println("1. Inserir Usuário");
                System.out.println("2. Inserir Espaço");
                System.out.println("3. Inserir Solicitação");
                System.out.println("4. Inserir Feriado");
                System.out.println("5. Avaliar Solicitação");
                System.out.println("6. Sair");
                System.out.print("Escolha uma opção: ");
                int opcao = scanner.nextInt();
                scanner.nextLine();

                switch (opcao) {
                    case 1 -> inserirUsuario(conn, scanner);
                    case 2 -> inserirEspaco(conn, scanner);
                    case 3 -> inserirSolicitacao(conn, scanner);
                    case 4 -> inserirFeriado(conn, scanner);
                    case 5 -> avaliarSolicitacao(conn, scanner);
                    case 6 -> {
                        System.out.println("Saindo...");
                        return;
                    }
                    default -> System.out.println("Opção inválida.");
                }
            }
        } catch (SQLException e) {
            System.err.println("Erro ao conectar ao banco de dados: " + e.getMessage());
        }
    }

    private static void inserirUsuario(Connection conn, Scanner scanner) {
        try {
            System.out.print("Nome: ");
            String nome = scanner.nextLine();
            System.out.print("Email: ");
            String email = scanner.nextLine();
            System.out.print("Senha: ");
            String senha = scanner.nextLine();
            System.out.print("Cargo: ");
            String cargo = scanner.nextLine();

            String sql = "INSERT INTO Usuario (nome, email, senha, cargo) VALUES (?, ?, ?, ?)";
            try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setString(1, nome);
                stmt.setString(2, email);
                stmt.setString(3, senha);
                stmt.setString(4, cargo);
                stmt.executeUpdate();
                System.out.println("Usuário inserido com sucesso!");
            }
        } catch (SQLException e) {
            System.err.println("Erro ao inserir usuário: " + e.getMessage());
        }
    }

    private static void inserirEspaco(Connection conn, Scanner scanner) {
        try {
            System.out.print("Nome do Espaço: ");
            String nome = scanner.nextLine();
            System.out.print("Equipamentos: ");
            String equipamentos = scanner.nextLine();

            String sql = "INSERT INTO Espaco (nome, equipamentos) VALUES (?, ?)";
            try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setString(1, nome);
                stmt.setString(2, equipamentos);
                stmt.executeUpdate();
                System.out.println("Espaço inserido com sucesso!");
            }
        } catch (SQLException e) {
            System.err.println("Erro ao inserir espaço: " + e.getMessage());
        }
    }

    private static void inserirSolicitacao(Connection conn, Scanner scanner) {
        try {
            System.out.print("ID do Usuário: ");
            int idUsuario = scanner.nextInt();
            System.out.print("ID do Espaço: ");
            int idEspaco = scanner.nextInt();
            scanner.nextLine(); 
            System.out.print("Data de Início (yyyy-MM-dd HH:mm:ss): ");
            String dataInicioStr = scanner.nextLine();
            System.out.print("Data de Fim (yyyy-MM-dd HH:mm:ss): ");
            String dataFimStr = scanner.nextLine();

            Timestamp dataInicio = Timestamp.valueOf(dataInicioStr);
            Timestamp dataFim = Timestamp.valueOf(dataFimStr);

            String sql = """
                INSERT INTO Solicitacao (id_usuario, id_espaco, data_solicitacao, data_inicio, data_fim)
                VALUES (?, ?, CURRENT_TIMESTAMP, ?, ?)
            """;
            try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setInt(1, idUsuario);
                stmt.setInt(2, idEspaco);
                stmt.setTimestamp(3, dataInicio); 
                stmt.setTimestamp(4, dataFim);
                stmt.executeUpdate();
                System.out.println("Solicitação inserida com sucesso!");
            }
        } catch (SQLException e) {
            System.err.println("Erro ao inserir solicitação: " + e.getMessage());
        } catch (IllegalArgumentException e) {
            System.err.println("Erro: Formato de data inválido. Use o formato yyyy-MM-dd HH:mm:ss.");
        }
    }

    private static void inserirFeriado(Connection conn, Scanner scanner) {
        try {
            System.out.print("Data do Feriado (yyyy-MM-dd): ");
            String data = scanner.nextLine();
            System.out.print("Descrição: ");
            String descricao = scanner.nextLine();

            String sql = "INSERT INTO Feriados (data, descricao) VALUES (?, ?)";
            try (PreparedStatement stmt = conn.prepareStatement(sql)) {
                stmt.setString(1, data);
                stmt.setString(2, descricao);
                stmt.executeUpdate();
                System.out.println("Feriado inserido com sucesso!");
            }
        } catch (SQLException e) {
            System.err.println("Erro ao inserir feriado: " + e.getMessage());
        }
    }
    
    private static void avaliarSolicitacao(Connection conn, Scanner scanner) {
        try {
            System.out.print("ID do Usuário Avaliador: ");
            int idUsuario = scanner.nextInt();
            System.out.print("ID da Solicitação: ");
            int idSolicitacao = scanner.nextInt();
            scanner.nextLine();
            System.out.print("Resultado da Avaliação (APROVADO/REJEITADO): ");
            String resultado = scanner.nextLine();
            System.out.print("Comentário: ");
            String comentario = scanner.nextLine();

            String consultaCargo = "SELECT cargo FROM Usuario WHERE id_usuario = ?";
            try (PreparedStatement cargoStmt = conn.prepareStatement(consultaCargo)) {
                cargoStmt.setInt(1, idUsuario);
                try (ResultSet rs = cargoStmt.executeQuery()) {
                    if (rs.next()) {
                        String cargo = rs.getString("cargo");
                        if (!cargo.equalsIgnoreCase("ADMINISTRADOR") && !cargo.equalsIgnoreCase("GESTOR")) {
                            System.out.println("Erro: Somente ADMINISTRADOR ou GESTOR podem avaliar solicitações.");
                            return;
                        }
                    } else {
                        System.out.println("Erro: Usuário não encontrado.");
                        return;
                    }
                }
            }

            String sqlAvaliacao = """
                INSERT INTO Avaliacao (id_solicitacao, id_usuario, data_avaliacao, resultado, comentario)
                VALUES (?, ?, CURRENT_TIMESTAMP, ?, ?)
            """;
            try (PreparedStatement stmtAvaliacao = conn.prepareStatement(sqlAvaliacao)) {
                stmtAvaliacao.setInt(1, idSolicitacao);
                stmtAvaliacao.setInt(2, idUsuario);
                stmtAvaliacao.setString(3, resultado.toUpperCase());
                stmtAvaliacao.setString(4, comentario);
                stmtAvaliacao.executeUpdate();
                System.out.println("Avaliação registrada com sucesso!");

                String novoStatus = resultado.equalsIgnoreCase("APROVADO") ? "APROVADO" : "REJEITADO";
                String sqlStatus = """
                    UPDATE Solicitacao
                    SET status = ?
                    WHERE id_solicitacao = ?
                """;
                try (PreparedStatement stmtStatus = conn.prepareStatement(sqlStatus)) {
                    stmtStatus.setString(1, novoStatus);
                    stmtStatus.setInt(2, idSolicitacao);
                    stmtStatus.executeUpdate();
                    System.out.println("Status da solicitação atualizado para " + novoStatus + ".");
                }
            }
        } catch (SQLException e) {
            System.err.println("Erro ao avaliar solicitação: " + e.getMessage());
        } catch (IllegalArgumentException e) {
            System.err.println("Erro: Formato de data inválido. Use o formato yyyy-MM-dd HH:mm:ss.");
        }
    }
    
}