package de.proskive.sampleeventlistenerprovider.provider;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.keycloak.common.util.UriUtils;

import java.io.BufferedReader;
import java.io.DataOutputStream;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URI;
import java.net.URL;
import java.net.URLEncoder;
import java.net.http.HttpClient;
import java.net.http.HttpRequest;
import java.net.http.HttpResponse;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.util.HashMap;

public class Utilities {

  public Utilities() {}


  public KeycloakResponsePOJO getAuthResponse(
      String restUser,
      String restPassword,
      String clientId,
      String grant_type,
      String keycloakUrl,
      String realm) {
    String url = keycloakUrl + "/realms/"+realm+"/protocol/openid-connect/token";
    String urlParameters =
        "username="
            + restUser
            + "&password="
            + restPassword
            + "&client_id="
            + clientId
            + "&grant_type="
            + grant_type;
    byte[] postData = urlParameters.getBytes(StandardCharsets.UTF_8);
    System.out.println(url);
    System.out.println(urlParameters);
    try {

      URL myurl = new URL(url);
      HttpURLConnection con = (HttpURLConnection) myurl.openConnection();

      con.setDoOutput(true);
      con.setRequestMethod("POST");
      con.setRequestProperty("User-Agent", "Java client");
      con.setRequestProperty("Content-Type", "application/x-www-form-urlencoded");

      try (DataOutputStream wr = new DataOutputStream(con.getOutputStream())) {

        wr.write(postData);
      }

      StringBuilder content;

      try (BufferedReader br = new BufferedReader(new InputStreamReader(con.getInputStream()))) {

        String line;
        content = new StringBuilder();

        while ((line = br.readLine()) != null) {
          content.append(line);
          content.append(System.lineSeparator());
        }
      }
      return new ObjectMapper().readValue(content.toString(), KeycloakResponsePOJO.class);

    } catch (IOException e) {
      e.printStackTrace();
    }
    return new KeycloakResponsePOJO();
  }

  public HttpResponse<String> getUserInKeycloak(
          String userId, String realm, String keycloakUrl, String accessToken)
          throws IOException, InterruptedException {
    HttpClient client = HttpClient.newHttpClient();
    System.out.println(keycloakUrl + "/admin/realms/"+realm+"/users/"+ userId);
    HttpRequest request =
            HttpRequest.newBuilder()
                    .uri(URI.create(keycloakUrl + "/admin/realms/"+realm+"/users/"+ userId))
                    .GET()
                    .header("Authorization", "Bearer " + accessToken)
                    .build();

    return client.send(request, HttpResponse.BodyHandlers.ofString());
  }

  // Users
  public void saveUserInAPProVe(
      String keycloakUserResponse, String userId, String backendServiceUrl, String accessToken)
      throws IOException, InterruptedException {
    HttpClient client = HttpClient.newHttpClient();
    HttpRequest request =
        HttpRequest.newBuilder()
            .uri(URI.create(backendServiceUrl + "/api/event/people/"+ userId))
            .POST(HttpRequest.BodyPublishers.ofString(keycloakUserResponse))
            .header("Authorization", "Bearer " + accessToken)
            .build();

    client.sendAsync(request, HttpResponse.BodyHandlers.ofString()).thenApply(HttpResponse::body)
            .thenAccept(System.out::println).join();
  }

  public void patchUserInAPProVe(
          String keycloakUserResponse, String backendServiceUrl, String accessToken, String userId)
      throws IOException, InterruptedException {
    HttpClient client = HttpClient.newHttpClient();
    HttpRequest request =
        HttpRequest.newBuilder()
            .uri(URI.create(backendServiceUrl + "/api/event/people/" + userId))
            .timeout(Duration.ofMinutes(2))
            .header("Content-Type", "application/json")
            .header("Authorization", "Bearer " + accessToken)
            .PUT(HttpRequest.BodyPublishers.ofString(keycloakUserResponse))
            .build();

    client.sendAsync(request, HttpResponse.BodyHandlers.ofString())
            .thenApply(response -> { System.out.println(response.statusCode());
              return response; } )
            .thenApply(HttpResponse::body)
            .thenAccept(System.out::println);
  }

  public void deleteUserInAPProVe(
          String backendServiceUrl, String accessToken, String userId)
          throws IOException, InterruptedException {
    HttpClient client = HttpClient.newHttpClient();
    HttpRequest request =
            HttpRequest.newBuilder()
                    .uri(URI.create(backendServiceUrl + "/api/event/people/"+userId))
                    .DELETE()
                    .header("Authorization", "Bearer " + accessToken)
                    .build();

    client.sendAsync(request, HttpResponse.BodyHandlers.ofString()).thenApply(HttpResponse::body)
            .thenAccept(System.out::println).join();
  }

  // Roles
  public void saveRoleInAPProVe(
          String keycloakRoleResponse, String backendServiceUrl,  String accessToken, String roleName)
          throws IOException, InterruptedException {
    HttpClient client = HttpClient.newHttpClient();
    String encodedRoleName = URLEncoder.encode(roleName, StandardCharsets.UTF_8);
    HttpRequest request =
            HttpRequest.newBuilder()
                    .uri(URI.create(backendServiceUrl + "/api/event/role?roleName="+encodedRoleName))
                    .POST(HttpRequest.BodyPublishers.ofString(keycloakRoleResponse))
                    .header("Authorization", "Bearer " + accessToken)
                    .build();

    client.sendAsync(request, HttpResponse.BodyHandlers.ofString()).thenApply(HttpResponse::body)
            .thenAccept(System.out::println).join();
  }

  public HttpResponse<String> patchRoleInAPProVe(
          String keycloakRoleResponse, String backendServiceUrl, String accessToken, String roleId)
          throws IOException, InterruptedException {

    HttpClient client = HttpClient.newHttpClient();
    HttpRequest request =
            HttpRequest.newBuilder()
                    .uri(URI.create(backendServiceUrl + "/api/event/role/" + roleId))
                    .method("PATCH",HttpRequest.BodyPublishers.ofString(keycloakRoleResponse))
                    .header("Authorization", "Bearer " + accessToken)
                    .build();

    return client.send(request, HttpResponse.BodyHandlers.ofString());
  }

  public void deleteRoleInAPProVe(
          String backendServiceUrl, String accessToken, String roleId)
          throws IOException, InterruptedException {
    HttpClient client = HttpClient.newHttpClient();
    HttpRequest request =
            HttpRequest.newBuilder()
                    .uri(URI.create(backendServiceUrl + "/api/event/role/"+roleId))
                    .DELETE()
                    .header("Authorization", "Bearer " + accessToken)
                    .build();

    client.sendAsync(request, HttpResponse.BodyHandlers.ofString()).thenApply(HttpResponse::body)
            .thenAccept(System.out::println).join();
  }

  // Add Roles to User
  public void saveRolesToUser(
          String keycloakUserResponse, String userId, String backendServiceUrl, String accessToken)
          throws IOException, InterruptedException {
    HttpClient client = HttpClient.newHttpClient();
    HttpRequest request =
            HttpRequest.newBuilder()
                    .uri(URI.create(backendServiceUrl + "/api/event/role/person/"+ userId))
                    .POST(HttpRequest.BodyPublishers.ofString(keycloakUserResponse))
                    .header("Authorization", "Bearer " + accessToken)
                    .build();

    client.sendAsync(request, HttpResponse.BodyHandlers.ofString()).thenApply(HttpResponse::body)
            .thenAccept(System.out::println).join();
  }

  // Remove Roles from User
  public void removeRolesFromUser(
          String keycloakUserResponse, String userId, String backendServiceUrl, String accessToken)
          throws IOException, InterruptedException {
    HttpClient client = HttpClient.newHttpClient();
    HttpRequest request =
            HttpRequest.newBuilder()
                    .uri(URI.create(backendServiceUrl + "/api/event/role/person/"+ userId))
                    .method("PATCH",HttpRequest.BodyPublishers.ofString(keycloakUserResponse))
                    .header("Authorization", "Bearer " + accessToken)
                    .build();

    client.sendAsync(request, HttpResponse.BodyHandlers.ofString()).thenApply(HttpResponse::body)
            .thenAccept(System.out::println).join();
  }
}
