package de.proskive.sampleeventlistenerprovider.provider;

import org.keycloak.representations.idm.UserRepresentation;

public class UserRepresentationPOJO extends UserRepresentation {
    private String eventType;

    public UserRepresentationPOJO() {
    }

    public String getEventType() {
        return eventType;
    }

    public void setEventType(String eventType) {
        this.eventType = eventType;
    }

    public static UserRepresentationPOJO deconvert(UserRepresentation userRepresentation, String eventType) {
        UserRepresentationPOJO userRepresentationPOJO = new UserRepresentationPOJO();
        userRepresentationPOJO.setEventType(eventType);
        userRepresentationPOJO.setAccess(userRepresentation.getAccess());
        userRepresentationPOJO.setAttributes(userRepresentation.getAttributes());
        userRepresentationPOJO.setClientConsents(userRepresentation.getClientConsents());
        userRepresentationPOJO.setClientRoles(userRepresentation.getClientRoles());
        userRepresentationPOJO.setCreatedTimestamp(userRepresentation.getCreatedTimestamp());
        userRepresentationPOJO.setCredentials(userRepresentation.getCredentials());
        userRepresentationPOJO.setDisableableCredentialTypes(userRepresentation.getDisableableCredentialTypes());
        userRepresentationPOJO.setEmail(userRepresentation.getEmail());
        userRepresentationPOJO.setEnabled(userRepresentation.isEnabled());
        userRepresentationPOJO.setFederatedIdentities(userRepresentation.getFederatedIdentities());
        userRepresentationPOJO.setEmailVerified(userRepresentation.isEmailVerified());
        userRepresentationPOJO.setFirstName(userRepresentation.getFirstName());
        userRepresentationPOJO.setGroups(userRepresentation.getGroups());
        userRepresentationPOJO.setId(userRepresentation.getId());
        userRepresentationPOJO.setLastName(userRepresentation.getLastName());
        userRepresentationPOJO.setNotBefore(userRepresentation.getNotBefore());
        userRepresentationPOJO.setOrigin(userRepresentation.getOrigin());
        userRepresentationPOJO.setRealmRoles(userRepresentation.getRealmRoles());
        userRepresentationPOJO.setRequiredActions(userRepresentation.getRequiredActions());
        userRepresentationPOJO.setSelf(userRepresentation.getSelf());
        userRepresentationPOJO.setServiceAccountClientId(userRepresentation.getServiceAccountClientId());
        userRepresentationPOJO.setSocialLinks(userRepresentation.getSocialLinks());
        userRepresentationPOJO.setUsername(userRepresentation.getUsername());
        return userRepresentationPOJO;
    }
}
