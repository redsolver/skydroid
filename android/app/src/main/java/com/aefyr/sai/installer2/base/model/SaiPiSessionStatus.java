package com.aefyr.sai.installer2.base.model;

import android.content.Context;


public enum SaiPiSessionStatus {
    CREATED, QUEUED, INSTALLING, INSTALLATION_SUCCEED, INSTALLATION_FAILED;

    public String getReadableName(Context c) {
        switch (this) {
            case CREATED:
                return "installer_state_created";
            case QUEUED:
                return "installer_state_queued";
            case INSTALLING:
                return "installer_state_installing";
            case INSTALLATION_SUCCEED:
                return "installer_state_installed";
            case INSTALLATION_FAILED:
                return "installer_state_failed";
        }

        throw new IllegalStateException("wtf");
    }
}
