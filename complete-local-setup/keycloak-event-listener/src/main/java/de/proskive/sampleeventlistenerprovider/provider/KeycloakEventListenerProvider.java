package de.proskive.sampleeventlistenerprovider.provider;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.keycloak.events.Event;
import org.keycloak.events.EventListenerProvider;
import org.keycloak.events.EventType;
import org.keycloak.events.admin.AdminEvent;
import org.keycloak.events.admin.OperationType;
import org.keycloak.events.admin.ResourceType;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.RealmModel;
import org.keycloak.models.UserModel;
import org.keycloak.models.utils.ModelToRepresentation;
import org.keycloak.representations.idm.UserRepresentation;

import java.io.IOException;
import java.net.http.HttpResponse;
import java.util.Map;

public class KeycloakEventListenerProvider implements EventListenerProvider {
  Utilities utilities = new Utilities();
  String restUser = System.getenv("REST_USER");
  String restPassword = System.getenv("REST_PASSWORD");
  String clientId = System.getenv("CLIENT_ID");
  String grant_type = System.getenv("GRANT_TYPE");
  String keycloakUrl = System.getenv("KEYCLOAK_URL");
  String backendServiceUrl = System.getenv("BACKEND_SERVICE_URL");
  String realm = System.getenv("KEYCLOAK_REALM");
  private final KeycloakSession keycloakSession;

  public KeycloakEventListenerProvider(KeycloakSession keycloakSession) {
    this.keycloakSession = keycloakSession;
  }

  @Override
  public void onEvent(Event event) {
    try {
      // User is updating his profile
//      if (event.getType().equals(EventType.UPDATE_PROFILE)) {
//        RealmModel realmModel = keycloakSession.realms().getRealm(realm);
//        UserModel userModel = keycloakSession.users().getUserById(realmModel, event.getUserId());
//        UserRepresentation userRepresentation = ModelToRepresentation.toRepresentation(keycloakSession, realmModel, userModel);
//        UserRepresentationPOJO userRepresentationPOJO = UserRepresentationPOJO.deconvert(userRepresentation, EventType.UPDATE_PROFILE.toString());
//        ObjectMapper objectMapper = new ObjectMapper();
//        String representation = objectMapper.writeValueAsString(userRepresentationPOJO);
//        System.out.println(representation);
//      }
      // User logs in and updates profile in APProVe
      if (event.getDetails() != null) {
        String username = event.getDetails().get("username");
        if (username != null) {
          if (!username.equals(restUser)) {
            System.out.println("Event Occurred:" + toString(event));
            if (event.getType().equals(EventType.LOGIN)) {
              UserModel userModel = keycloakSession.getContext().getAuthenticationSession().getAuthenticatedUser();
              RealmModel realmModel = keycloakSession.realms().getRealm(realm);
              UserRepresentation userRepresentation = ModelToRepresentation.toRepresentation(keycloakSession, realmModel, userModel);
              UserRepresentationPOJO userRepresentationPOJO = UserRepresentationPOJO.deconvert(userRepresentation, EventType.LOGIN.toString());
              ObjectMapper objectMapper = new ObjectMapper();
              String representation = objectMapper.writeValueAsString(userRepresentationPOJO);
              System.out.println(representation);
              KeycloakResponsePOJO authResponse =
                      utilities.getAuthResponse(restUser, restPassword, clientId, grant_type, keycloakUrl, realm);
              utilities.patchUserInAPProVe(
                      representation, backendServiceUrl, authResponse.getAccess_token(), userRepresentation.getId());
            }
          }
        }
      }
    } catch (IOException | InterruptedException e) {
      e.printStackTrace();
    }
  }

  @Override
  public void onEvent(AdminEvent adminEvent, boolean b) {

    System.out.println("Admin Event Occurred:" + toString(adminEvent));
    System.out.println("Operation-Type: " + adminEvent.getOperationType());
    System.out.println("ResourceType: " + adminEvent.getResourceTypeAsString());
    System.out.println("Representation: " + adminEvent.getRepresentation());
    System.out.println("clientId: " + clientId);
    System.out.println("keycloakUrl: " + keycloakUrl);
    System.out.println("backendServiceUrl: " + backendServiceUrl);
    // User specific admin events
    if (adminEvent.getResourceType().equals(ResourceType.USER)) {
      try {
        KeycloakResponsePOJO authResponse =
                utilities.getAuthResponse(restUser, restPassword, clientId, grant_type, keycloakUrl, realm);
        String userId = adminEvent.getResourcePath().replace("users/", "");
        System.out.println("User Id: "+userId);
        if (adminEvent.getOperationType().equals(OperationType.CREATE)) {
          utilities.saveUserInAPProVe(
                  adminEvent.getRepresentation(),userId,  backendServiceUrl, authResponse.getAccess_token());
          System.out.println(adminEvent.getRepresentation());
        }
        if (adminEvent.getOperationType().equals(OperationType.UPDATE)) {
          utilities.patchUserInAPProVe(
                  adminEvent.getRepresentation(), backendServiceUrl, authResponse.getAccess_token(), userId);
          System.out.println(adminEvent.getRepresentation());
        }
        if (adminEvent.getOperationType().equals(OperationType.DELETE)) {
          utilities.deleteUserInAPProVe(backendServiceUrl,
                  authResponse.getAccess_token(), userId);
        }
      } catch (IOException | InterruptedException e) {
        e.printStackTrace();
      }
    }
    if (adminEvent.getResourceType().equals(ResourceType.REALM_ROLE)) {
      try {
        KeycloakResponsePOJO authResponse =
                utilities.getAuthResponse(restUser, restPassword, clientId, grant_type, keycloakUrl, realm);
        System.out.println(adminEvent.getResourcePath());
        if (adminEvent.getOperationType().equals(OperationType.CREATE)) {
          String roleName = adminEvent.getResourcePath().replace("roles/", "");
          System.out.println("role Id: " + roleName);
          utilities.saveRoleInAPProVe(
                  adminEvent.getRepresentation(), backendServiceUrl, authResponse.getAccess_token(), roleName);
          System.out.println(adminEvent.getRepresentation());
        }
        if (adminEvent.getOperationType().equals(OperationType.UPDATE)) {
          String roleId = adminEvent.getResourcePath().replace("roles-by-id/", "");
          System.out.println("role Id: " + roleId);
          HttpResponse<String> saveRequest = utilities.patchRoleInAPProVe(
                  adminEvent.getRepresentation(), backendServiceUrl, authResponse.getAccess_token(), roleId);
          System.out.println(adminEvent.getRepresentation());
          System.out.println("updated Role in APProVe= " + saveRequest.body());
        }
        if (adminEvent.getOperationType().equals(OperationType.DELETE)) {
          String roleId = adminEvent.getResourcePath().replace("roles-by-id/", "");
          System.out.println("role Id: " + roleId);
          utilities.deleteRoleInAPProVe(
                  backendServiceUrl, authResponse.getAccess_token(), roleId);
        }
      } catch (IOException | InterruptedException e) {
        e.printStackTrace();
      }
    }
    if (adminEvent.getResourceType().equals(ResourceType.REALM_ROLE_MAPPING)) {
      KeycloakResponsePOJO authResponse =
              utilities.getAuthResponse(restUser, restPassword, clientId, grant_type, keycloakUrl, realm);
      try {
        if (adminEvent.getOperationType().equals(OperationType.CREATE)) {
          String userId = adminEvent.getResourcePath().replace("users/", "").replace("/role-mappings/realm", "");
          System.out.println("User Id: "+userId);
          utilities.saveRolesToUser(
                  adminEvent.getRepresentation(), userId , backendServiceUrl, authResponse.getAccess_token());
        }
        if (adminEvent.getOperationType().equals(OperationType.DELETE)) {
          String userId = adminEvent.getResourcePath().replace("users/", "").replace("/role-mappings/realm", "");
          System.out.println("User Id: "+userId);
          utilities.removeRolesFromUser(
                  adminEvent.getRepresentation(), userId , backendServiceUrl, authResponse.getAccess_token());
        }
      } catch (IOException | InterruptedException e) {
        e.printStackTrace();
      }
    }
  }

  @Override
  public void close() {}

  private String toString(Event event) throws IOException, InterruptedException {
    StringBuilder sb = new StringBuilder();
    sb.append("type=");

    sb.append(event.getType());

    sb.append(", realmId=");

    sb.append(event.getRealmId());

    sb.append(", clientId=");

    sb.append(event.getClientId());

    sb.append(", userId=");

    sb.append(event.getUserId());

    sb.append(", ipAddress=");

    sb.append(event.getIpAddress());

    if (event.getError() != null) {

      sb.append(", error=");

      sb.append(event.getError());
    }

    if (event.getDetails() != null) {

      for (Map.Entry<String, String> e : event.getDetails().entrySet()) {

        sb.append(", ");

        sb.append(e.getKey());

        if (e.getValue() == null || e.getValue().indexOf(' ') == -1) {

          sb.append("=");

          sb.append(e.getValue());

        } else {

          sb.append("='");

          sb.append(e.getValue());

          sb.append("'");
        }
      }
    }

    return sb.toString();
  }

  private String toString(AdminEvent adminEvent) {

    StringBuilder sb = new StringBuilder();

    sb.append("operationType=");

    sb.append(adminEvent.getOperationType());

    sb.append(", realmId=");

    sb.append(adminEvent.getAuthDetails().getRealmId());

    sb.append(", clientId=");

    sb.append(adminEvent.getAuthDetails().getClientId());

    sb.append(", userId=");

    sb.append(adminEvent.getAuthDetails().getUserId());

    sb.append(", ipAddress=");

    sb.append(adminEvent.getAuthDetails().getIpAddress());

    sb.append(", resourcePath=");

    sb.append(adminEvent.getResourcePath());

    if (adminEvent.getError() != null) {

      sb.append(", error=");

      sb.append(adminEvent.getError());
    }

    return sb.toString();
  }

}
