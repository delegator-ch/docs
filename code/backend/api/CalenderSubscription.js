import React, { useState, useEffect } from 'react';
import axios from 'axios';
import { 
  Container, Typography, Card, CardContent, Button, List,
  ListItem, ListItemText, ListItemSecondaryAction, IconButton,
  TextField, Dialog, DialogTitle, DialogContent, DialogActions,
  Tooltip, CircularProgress, Snackbar, Alert
} from '@mui/material';
import { CalendarMonth, ContentCopy, Delete, Add, Refresh } from '@mui/icons-material';

// Assuming you have an API service configured
import { API_BASE_URL } from '../config';

const CalendarSubscriptions = () => {
  const [subscriptions, setSubscriptions] = useState([]);
  const [loading, setLoading] = useState(true);
  const [dialogOpen, setDialogOpen] = useState(false);
  const [selectedCalendar, setSelectedCalendar] = useState(null);
  const [calendars, setCalendars] = useState([]);
  const [notification, setNotification] = useState({ open: false, message: '', severity: 'info' });

  useEffect(() => {
    // Fetch subscriptions
    fetchSubscriptions();
    // Fetch available calendars
    axios.get(`${API_BASE_URL}/calendars/`)
      .then(response => {
        setCalendars(response.data);
      })
      .catch(error => {
        console.error('Error fetching calendars:', error);
        showNotification('Error loading calendars', 'error');
      });
  }, []);

  const fetchSubscriptions = () => {
    setLoading(true);
    axios.get(`${API_BASE_URL}/subscriptions/`)
      .then(response => {
        setSubscriptions(response.data);
        setLoading(false);
      })
      .catch(error => {
        console.error('Error fetching subscriptions:', error);
        showNotification('Error loading subscriptions', 'error');
        setLoading(false);
      });
  };

  const createCalendarSubscription = () => {
    if (!selectedCalendar) return;
    
    setLoading(true);
    axios.get(`${API_BASE_URL}/subscriptions/calendar/${selectedCalendar}/`)
      .then(response => {
        // Add new subscription to the list
        setSubscriptions([...subscriptions, response.data]);
        setDialogOpen(false);
        setSelectedCalendar(null);
        setLoading(false);
        showNotification('Subscription created successfully', 'success');
      })
      .catch(error => {
        console.error('Error creating subscription:', error);
        showNotification('Error creating subscription', 'error');
        setLoading(false);
      });
  };

  const createAllEventsSubscription = () => {
    setLoading(true);
    axios.get(`${API_BASE_URL}/subscriptions/user/`)
      .then(response => {
        // Add new subscription to the list
        setSubscriptions([...subscriptions, response.data]);
        setLoading(false);
        showNotification('All events subscription created', 'success');
      })
      .catch(error => {
        console.error('Error creating all events subscription:', error);
        showNotification('Error creating subscription', 'error');
        setLoading(false);
      });
  };

  const revokeSubscription = (id) => {
    setLoading(true);
    axios.delete(`${API_BASE_URL}/subscriptions/${id}/revoke/`)
      .then(() => {
        // Remove from list
        setSubscriptions(subscriptions.filter(sub => sub.id !== id));
        setLoading(false);
        showNotification('Subscription revoked', 'success');
      })
      .catch(error => {
        console.error('Error revoking subscription:', error);
        showNotification('Error revoking subscription', 'error');
        setLoading(false);
      });
  };

  const copyToClipboard = (text) => {
    navigator.clipboard.writeText(text)
      .then(() => {
        showNotification('URL copied to clipboard', 'success');
      })
      .catch(err => {
        console.error('Could not copy text: ', err);
        showNotification('Failed to copy URL', 'error');
      });
  };

  const showNotification = (message, severity) => {
    setNotification({
      open: true,
      message,
      severity
    });
  };

  const handleCloseNotification = () => {
    setNotification({ ...notification, open: false });
  };

  return (
    <Container maxWidth="md">
      <Typography variant="h4" gutterBottom sx={{ mt: 4 }}>
        Calendar Subscriptions
      </Typography>
      
      <Typography variant="body1" paragraph>
        Subscribe to your calendars in external applications like Google Calendar, Apple Calendar, or Outlook.
        These links will sync automatically when events are updated.
      </Typography>
      
      <div style={{ display: 'flex', gap: '16px', marginBottom: '24px' }}>
        <Button 
          variant="contained" 
          startIcon={<Add />}
          onClick={() => setDialogOpen(true)}
        >
          New Subscription
        </Button>
        
        <Button 
          variant="outlined" 
          startIcon={<CalendarMonth />}
          onClick={createAllEventsSubscription}
        >
          Subscribe to All My Events
        </Button>
        
        <Button 
          variant="outlined" 
          startIcon={<Refresh />}
          onClick={fetchSubscriptions}
        >
          Refresh
        </Button>
      </div>
      
      {loading ? (
        <div style={{ display: 'flex', justifyContent: 'center', padding: '32px' }}>
          <CircularProgress />
        </div>
      ) : subscriptions.length === 0 ? (
        <Card>
          <CardContent>
            <Typography variant="body1" align="center">
              No calendar subscriptions found. Create one to get started.
            </Typography>
          </CardContent>
        </Card>
      ) : (
        <List>
          {subscriptions.map((subscription) => (
            <Card key={subscription.id} sx={{ mb: 2 }}>
              <CardContent>
                <Typography variant="h6">
                  {subscription.name || (subscription.calendar_id 
                    ? `${subscription.calendar_name} Calendar` 
                    : "All My Events")}
                </Typography>
                
                <Typography variant="body2" color="text.secondary" gutterBottom>
                  Created: {new Date(subscription.created).toLocaleString()}
                  {subscription.last_used && (
                    <> • Last used: {new Date(subscription.last_used).toLocaleString()}</>
                  )}
                </Typography>
                
                <TextField
                  fullWidth
                  variant="outlined"
                  margin="normal"
                  size="small"
                  value={subscription.subscription_url}
                  InputProps={{
                    readOnly: true,
                    endAdornment: (
                      <Tooltip title="Copy URL">
                        <IconButton 
                          onClick={() => copyToClipboard(subscription.subscription_url)}
                          edge="end"
                        >
                          <ContentCopy />
                        </IconButton>
                      </Tooltip>
                    ),
                  }}
                />
                
                <div style={{ marginTop: '16px', display: 'flex', justifyContent: 'space-between' }}>
                  <Button
                    variant="outlined"
                    size="small"
                    startIcon={<CalendarMonth />}
                    onClick={() => window.open(subscription.subscription_url, '_blank')}
                  >
                    Download .ics File
                  </Button>
                  
                  <Button
                    variant="outlined"
                    color="error"
                    size="small"
                    startIcon={<Delete />}
                    onClick={() => revokeSubscription(subscription.id)}
                  >
                    Revoke Access
                  </Button>
                </div>
              </CardContent>
            </Card>
          ))}
        </List>
      )}
      
      {/* Dialog for creating new subscription */}
      <Dialog open={dialogOpen} onClose={() => setDialogOpen(false)} maxWidth="sm" fullWidth>
        <DialogTitle>Create Calendar Subscription</DialogTitle>
        <DialogContent>
          <Typography variant="body2" paragraph>
            Select a calendar to create a subscription URL. You can use this URL 
            to subscribe to this calendar in external applications.
          </Typography>
          
          <TextField
            select
            fullWidth
            label="Select Calendar"
            value={selectedCalendar || ''}
            onChange={(e) => setSelectedCalendar(e.target.value)}
            SelectProps={{
              native: true,
            }}
            margin="normal"
          >
            <option value="">Select a calendar</option>
            {calendars.map((calendar) => (
              <option key={calendar.id} value={calendar.id}>
                {calendar.organisation_details.name}
              </option>
            ))}
          </TextField>
        </DialogContent>
        <DialogActions>
          <Button onClick={() => setDialogOpen(false)}>Cancel</Button>
          <Button 
            onClick={createCalendarSubscription} 
            variant="contained"
            disabled={!selectedCalendar}
          >
            Create Subscription
          </Button>
        </DialogActions>
      </Dialog>
      
      {/* Notification snackbar */}
      <Snackbar 
        open={notification.open} 
        autoHideDuration={6000} 
        onClose={handleCloseNotification}
        anchorOrigin={{ vertical: 'bottom', horizontal: 'center' }}
      >
        <Alert 
          onClose={handleCloseNotification} 
          severity={notification.severity}
          variant="filled"
        >
          {notification.message}
        </Alert>
      </Snackbar>
    </Container>
  );
};

export default CalendarSubscriptions;